function pw = get_password(varargin)
if ispc
    userDir = winqueryreg('HKEY_CURRENT_USER',...
        ['Software\Microsoft\Windows\CurrentVersion\' ...
         'Explorer\Shell Folders'],'Personal');
else
    userDir = char(java.lang.System.getProperty('user.home'));
end
d.pwmat_location = fullfile(userDir,'enc_mount','haba_pw.mat');
%%
v = inputParser;
addParameter(v,'pwmat_location',d.pwmat_location);
parse(v,varargin{:});
v = v.Results;clear d;
%%
%if you are storing the password in a file (which should usually be
%encrypted)
askuser = false;
if (exist(fileparts(v.pwmat_location),'dir')==7)
    if (exist(v.pwmat_location,'file')==2)
        pw = load(v.pwmat_location);
        pw = pw.ssh;
    else
        fprintf('Not mounted?\n');
        askuser = true;
    end
else
    askuser = true;
end

%normal get password from user
if askuser
    pw.ssh = input('pw ssh:\n','s');
    % Remove password from matlab command history
    fprintf(repmat('\b',1,1+length(pw.ssh)));%from screen
    fprintf('Got it.\n')
    % Get instance to the Command History
    cmdhist = com.mathworks.mde.cmdhist.AltHistory.getInstance;
    % Retrieve the Command History Table
    chtable = findjobj(cmdhist,'property',{'name', 'CommandHistoryTable'});
    % Select last row row
    nrows = chtable.getRowCount;
    chtable.setRowSelectionInterval(nrows-1, nrows-1)
    % Delete selected rows
    chtable.deleteSelectedCommands;
end
end