function zipf = scpPackageProject()
%SCPPACKAGEPROJECT  SCPプロジェクトを git 管理用に切り出して zip に固める.
%
%   ZIPF = SCPPACKAGEPROJECT()
%   ホワイトリスト方式で必要ファイルだけを集め (生成物・キャッシュは除外),
%   README.md / .gitignore を同梱して <proj>/scp_landing_project.zip を作る.
%   展開先で git init してそのまま管理できる構成.
%
%   See also SCPCODEGENZIP, README.MD
here = fileparts(mfilename('fullpath'));  proj = fileparts(here);
stg = fullfile(proj,'project_pkg');
if exist(stg,'dir'), rmdir(stg,'s'); end
mkdir(stg);

%% --- ホワイトリスト ---
rootFiles = {'README.md','setup.m'};
dirsFull  = {'config','docs','examples'};        % 丸ごと (無ければスキップ)
for i = 1:numel(rootFiles)
    copyfile(fullfile(proj,rootFiles{i}), fullfile(stg,rootFiles{i}));
end
inc = {};
for i = 1:numel(dirsFull)
    if exist(fullfile(proj,dirsFull{i}),'dir')
        copyfile(fullfile(proj,dirsFull{i}), fullfile(stg,dirsFull{i}));
        inc{end+1} = dirsFull{i}; %#ok<AGROW>
    end
end
dirsFull = inc;
%% src: パッケージ + API .m + cpp ソース (codegen生成物・バイナリは除外)
mkdir(fullfile(stg,'src'));  mkdir(fullfile(stg,'src','cpp'));
copyfile(fullfile(proj,'src','+scpk'), fullfile(stg,'src','+scpk'));
dm = dir(fullfile(proj,'src','*.m'));
for i = 1:numel(dm)
    copyfile(fullfile(dm(i).folder,dm(i).name), fullfile(stg,'src',dm(i).name));
end
dc = [dir(fullfile(proj,'src','cpp','*.cpp')); dir(fullfile(proj,'src','cpp','*.hpp')); ...
      dir(fullfile(proj,'src','cpp','*.c'))];
for i = 1:numel(dc)
    copyfile(fullfile(dc(i).folder,dc(i).name), fullfile(stg,'src','cpp',dc(i).name));
end
%% util: .m のみ (legacy 含む)
mkdir(fullfile(stg,'util'));  mkdir(fullfile(stg,'util','legacy'));
dm = dir(fullfile(proj,'util','*.m'));
for i = 1:numel(dm)
    copyfile(fullfile(dm(i).folder,dm(i).name), fullfile(stg,'util',dm(i).name));
end
dm = dir(fullfile(proj,'util','legacy','*.m'));
for i = 1:numel(dm)
    copyfile(fullfile(dm(i).folder,dm(i).name), fullfile(stg,'util','legacy',dm(i).name));
end
%% 計画解 (クイックスタート用) のみ results から同梱
mkdir(fullfile(stg,'results'));
for f = {'landing_vert.mat','landing_falcon9.mat'}
    src = fullfile(proj,'results',f{1});
    if exist(src,'file'), copyfile(src, fullfile(stg,'results',f{1})); end
end

%% --- .gitignore ---
fid = fopen(fullfile(stg,'.gitignore'),'w','n','UTF-8');
fprintf(fid, ['# ビルド/生成物 (再生成可能)\n' ...
    '*.mexw64\n*.asv\n*.exe\n' ...
    'src/cpp/codegen_*/\n' ...
    'embedded/\nembedded_pkg/\nproject_pkg/\n' ...
    'scp_landing_embedded.zip\nscp_landing_project.zip\n' ...
    '# 実行結果 (計画解のクイックスタート2件のみ管理)\n' ...
    'results/*\n' ...
    '!results/landing_vert.mat\n' ...
    '!results/landing_falcon9.mat\n']);
fclose(fid);

%% --- zip ---
zipf = fullfile(proj,'scp_landing_project.zip');
if exist(zipf,'file'), delete(zipf); end
zip(zipf, [cellfun(@(n) fullfile(stg,n), rootFiles,'Uni',0), ...
           cellfun(@(n) fullfile(stg,n), [dirsFull, {'src','util','results'}],'Uni',0), ...
           {fullfile(stg,'.gitignore')}]);
d = dir(zipf);
fprintf('プロジェクトzip: %s (%.0f KB)\n', zipf, d.bytes/1024);
end
