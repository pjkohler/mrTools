% mrSaveView.m
%
%        $Id: mrQuit.m 1942 2010-12-16 18:14:41Z julien $ 
%      usage: mrSaveView(v)
%         by: justin gardner, taken out from mrQuit by julien besle
%       date: 07/11/08, 2011/08/05
%    purpose: saves view and view settings in session directory

function mrSaveView(v)

% remember figure location
if isfield(v,'fignum')
    fig = viewGet(v,'fignum');
    if ~isempty(fig)
      mrSetFigLoc('mrLoadRetGUI',get(fig,'Position'));
    end
elseif isfield(v,'figure') && ~isempty(v.figure)
    mrSetFigLoc('mrLoadRetGUI',v.figure.Position)
else
    mrErrorDlg('(mrSaveView) problem saving figure position')
end

% remember settings that are not in view
mrGlobals;
if isfield(MLR,'panels')
  viewSettings.panels = MLR.panels;
else
  viewSettings.panels = [];
end

homeDir = viewGet(v,'homeDir');
try
  disppercent(-inf,sprintf('(mrSaveView) Saving %s/mrLastView',homeDir));
        % save the view in the current directory
  view = v;
  % replace view.figure with figure number (to prevent opening on loading
  % of the .mat file)
  view.figure = mlrGetFignum(view);
  
  if getfield(whos('view'),'bytes')<2e9
    save(fullfile(homeDir,'mrLastView'), 'view','viewSettings', '-V6');
  else
    mrWarnDlg('(mrSaveView) Variable view is more than 2Gb, using option -v7.3 to save');
    save(fullfile(homeDir,'mrLastView'), 'view', 'viewSettings', '-v7.3');
  end
  % save .mrDefaults in the home directory
  disppercent(inf);
catch
  disppercent(inf);
  mrErrorDlg('(mrQuit) Could not save mrLastView.mat');
end
