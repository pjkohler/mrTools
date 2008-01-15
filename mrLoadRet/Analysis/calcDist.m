% calcDist.m
%
%	$Id$	
%      usage: calcDist()
%         by: eli merriam
%       date: 11/28/07
%    purpose: 
%
function retval = calcDist(view, method)

% check arguments
if ~any(nargin == [1 2])
  help calcDist
  return

end
retval = [];
if ieNotDefined('method'); method = 'pairs'; end


% baseCoords contains the mapping from pixels in the displayed slice to
% voxels in the current base volume.
baseCoords = viewGet(view,'cursliceBaseCoords');
if isempty(baseCoords)
  mrErrorDlg('Load base anatomy before drawing an ROI');
end

% get the base CoordMap for the current flat patch
corticalDepth = viewGet(view, 'corticalDepth');
baseCoordMap = viewGet(view,'baseCoordMap');
if isempty(baseCoordMap)
  sprintf(disp('You cannot use this function unless you are viewing a flatpatch with a baseCoordMap'));
  return;
end


if strcmp(method, 'roi')
  coords = viewGet(view, 'roicoords');
  coords = cat(1,coords(2,:), coords(1,:), coords(3,:))';
  
  roiBaseCoords = round(xformROIcoords(roiCoords,inv(baseXform)*roiXform,roiVoxelSize,baseVoxelSize));
  
else
  % Select main axes of view figure for user input
  fig = viewGet(view,'figNum');
  gui = guidata(fig);
  set(fig,'CurrentAxes',gui.axis);
  
  % pick some points
  [xi yi] = getpts;
  
  % draw the lines temporarily
  switch lower(method)
    case {'segments'}
      line(xi,yi);
    case {'pairs'}
      % ignore the last point if there are an odd number of inputs
      if ~iseven(length(xi))
        xi = xi(1:end-1);
        yi = yi(1:end-1);
      end
      for p=1:2:length(xi)
        line(xi(p:p+1), yi(p:p+1));
      end
      drawnow;  
  end
  % Extract coordinates in base reference frame
  baseX = baseCoords(:,:,1);
  baseY = baseCoords(:,:,2);
  baseZ = baseCoords(:,:,3);
  lineInd = sub2ind(size(baseX), round(yi), round(xi));
  x = baseX(lineInd);
  y = baseY(lineInd);
  z = baseZ(lineInd);
  coords = [y x z];
end


% load the appropriate surface files
disp(sprintf('Loading %s', baseCoordMap.innerFileName));
surf.inner = loadSurfOFF(fullfile(baseCoordMap.flatDir, baseCoordMap.innerFileName));
disp(sprintf('Loading %s', baseCoordMap.outerFileName));
surf.outer = loadSurfOFF(fullfile(baseCoordMap.flatDir, baseCoordMap.outerFileName));

% build up a mrMesh-style structure, taking account of the current corticalDepth
mesh.vertices = surf.inner.vtcs+corticalDepth*(surf.outer.vtcs-surf.inner.vtcs);
mesh.faceIndexList  = surf.inner.tris;

% calculate the connection matrix
[mesh.uniqueVertices,mesh.vertsToUnique,mesh.UniqueToVerts] = unique(mesh.vertices,'rows'); 
mesh.uniqueFaceIndexList = findUniqueFaceIndexList(mesh); 
mesh.connectionMatrix = findConnectionMatrix(mesh);

% get the coordinates of the vertices that are closest to the selected points
[nearestVtcs, distances] = assignToNearest(mesh.uniqueVertices, coords);

% complain if any of the selected points are far away
for i=1:length(distances)
  if (distances>1)
    disp(sprintf('Point %i is %f from the nearest surface vertex', i, distances(i)));
  end
end

% find the distance of all vertices from their neighbours 
scaleFactor = [1 1 1];
D = find3DNeighbourDists(mesh,scaleFactor); 

retval = [];
switch lower(method)
  case {'segments'}
    % calculate length of each segment (1-2, 2-3, 3-4)
    for p=1:length(nearestVtcs)-1
      dist = dijkstra(D, nearestVtcs(p))';
      retval(p) = dist(nearestVtcs(p+1));
    end 
 case {'pairs'}
    % calculate lengths of a bunch of pairs (1-2, 3-4, 5-6)
    for p=1:2:length(nearestVtcs)
      dist = dijkstra(D, nearestVtcs(p))';
      retval(end+1) = dist(nearestVtcs(p+1));
    end
  case {'roi'}
    % calculate lengths of each point from the first coordinate
    dist = dijkstra(D, nearestVtcs(1))';
    retval = dist(nearestVtcs);
  otherwise
    mesh.dist = dijkstra(D, nearestVtcs(1))';
end

if nargout == 1
  retval = dist(nearestVtcs);
end

return;


% patch('vertices', mesh.uniqueVertices, 'faces', mesh.uniqueFaceIndexList, ...
%       'FaceVertexCData', mesh.dist, ...
%       'facecolor', 'interp','edgecolor', 'none');


% baseX = zeros(1,length(xi));
% baseY = zeros(1,length(xi));
% baseZ = zeros(1,length(xi));
% for p=1:length(xi)
%   baseX(p) = baseCoordMap.innerCoords(xi(p), yi(p), 1, 1);
%   baseY(p) = baseCoordMap.innerCoords(xi(p), yi(p), 1, 2);
%   baseZ(p) = baseCoordMap.innerCoords(xi(p), yi(p), 1, 3);
% end

% coords = [baseX' baseY' baseZ'];


