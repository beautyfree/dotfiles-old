# Config syncing

# Dotbot now uses $SHELL for all it's execution, so we force `bash` so that we
#   have something that'll run on both existing and fresh machines.
dotbot = 'env SHELL=/bin/bash meta/dotbot/bin/dotbot'

# This is more or less the setup process
namespace :meta do

    task :homebrew => :dotbot do
        # No brewfile, because we don't have homebrew installed yet ^_^
        sh "#{dotbot} -c meta/homebrew/install.conf.yaml"
    end

    # Underlying tool for scripting and linking
    task :dotbot do
        # Eventually I think I can replace dotbot with Open3.capture3 and sugar
        # of my own, but let's just get this going first.
        sh "git submodule update --init --recursive meta/dotbot"
    end
end

task :shell => [:'meta:homebrew', :'meta:dotbot'] do
    sh 'brew bundle --verbose --file=shell/Brewfile'
    sh "#{dotbot} -c shell/install.conf.yaml"
end

task :zsh => [:'meta:homebrew', :'meta:dotbot'] do
    sh 'brew bundle --verbose --file=zsh/Brewfile'
    sh "#{dotbot} -c zsh/install.conf.yaml"
end

task :ssh => [:'meta:homebrew', :'meta:dotbot'] do
    sh "#{dotbot} -c ssh/install.conf.yaml"
end

task :git => [
  :'meta:homebrew',
  :'meta:dotbot',
  ] do
    sh 'brew bundle --verbose --file=git/Brewfile'
    sh "#{dotbot} -c git/install.conf.yaml"
end

task :fonts => [:'meta:homebrew'] do
    sh 'brew bundle --verbose --file=fonts/Brewfile'
end

task :karabiner => [:'meta:homebrew', :'meta:dotbot'] do
    sh 'brew bundle --verbose --file=karabiner/Brewfile'
    sh "#{dotbot} -c karabiner/install.conf.yaml"
end

task :apps => [:'meta:homebrew'] do
    sh 'brew bundle --verbose --file=apps/Brewfile'
end

task :alfred => [:'meta:homebrew'] do
    sh 'brew bundle --verbose --file=alfred/Brewfile'
end

task :common => [:'meta:dotbot'] do
    sh "#{dotbot} -c common/install.conf.yaml"
end

task :nodejs => [:'meta:homebrew', :'meta:dotbot'] do
    sh 'brew bundle --verbose --file=nodejs/Brewfile'
    sh "#{dotbot} -c nodejs/install.conf.yaml"
end

task :macos => [:'meta:homebrew'] do
    sh 'env SHELL=/bin/bash chmod +x ./macos/defaults.sh'
    sh 'env SHELL=/bin/bash ./macos/defaults.sh'
end

# task :sublime => [:'meta:homebrew', :'meta:dotbot'] do
#     sh 'brew bundle --verbose --file=sublime/Brewfile'
#     sh "#{dotbot} -c sublime/install.conf.yaml"
# end

# task :vscode => [:'meta:homebrew', :'meta:dotbot'] do
#     sh 'brew bundle --verbose --file=vscode/Brewfile'
#     sh "#{dotbot} -c vscode/install.conf.yaml"
# end

task :default => [
  :shell,
  :git,
  :zsh,
  :ssh,
  :fonts,
  :karabiner,
  :apps,
  :nodejs,
  :alfred,
  :common,
  :macos,
#   :sublime,
#   :vscode,
]

task :install => [
  :default
]
