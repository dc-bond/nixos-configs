{ pkgs, ... }: 

{

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraConfig = ''
      " set colorscheme
      colorscheme nord

      " general settings
      set path+=**					          " Searches current directory recursively.
      set wildmenu					          " Display all matches when tab complete.
      set incsearch                   " Incremental search
      set hidden                      " Needed to keep multiple buffers open
      set nobackup                    " No auto backups
      set noswapfile                  " No swap
      set t_Co=256                    " Set if term supports 256 colors.
      set number relativenumber       " Display line numbers
      set clipboard=unnamedplus       " Copy/paste between vim and other programs.
      syntax enable
      "let g:rehash256 = 1

      " statusline
      let g:lightline = {
            \ 'colorscheme': 'nord',
            \ }
      
      " always show statusline
      set laststatus=2

      " fix aut-indentation for YAML files
      augroup yaml_fix
          autocmd!
          autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab indentkeys-=0# indentkeys-=<:>
      augroup END

      " mouse scrolling
      set mouse=nicr
      set mouse=a

      " reset cursor to beam on exiting back to terminal
      "augroup RestoreCursorShapeOnExit
      "  autocmd!
      "  autocmd VimLeave * set guicursor=a:ver25
      "augroup END

      " fix sizing bug with alacritty terminal
      autocmd VimEnter * :silent exec "!kill -s SIGWINCH $PPID"
    '';
    plugins = with pkgs.vimPlugins; [
      nord-nvim
      fzf-vim
      lightline-vim
      #comfortable-motion.vim
      #vim-beancount
    ];
  };

}