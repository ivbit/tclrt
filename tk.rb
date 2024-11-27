#! /usr/bin/ruby

# https://tkdocs.com/tutorial/firstexample.html

# Install:
# Ruby warns that Ruby/Tk requires Tcl/Tk 8.5, or Tcl/Tk 8.4 and
# that Ruby/Tk may work incorrectly with Tcl/Tk 8.6.
# To install Ruby/Tk with Tcl/Tk 8.6 bindings:
#
# sudo apt install tk-dev ruby3.1-dev
#
# sudo gem install tk -- --with-tcltkversion=8.6 \
# --with-tcl-lib=/usr/lib/x86_64-linux-gnu \
# --with-tk-lib=/usr/lib/x86_64-linux-gnu \
# --with-tcl-include=/usr/include/tcl8.6 \
# --with-tk-include=/usr/include/tcl8.6 \
# --enable-pthread

# 1 meter == 3.281 feets

require 'tk'
require 'tkextlib/tile'

root = TkRoot.new {title "Feet to Meters (Ruby)"}
content = Tk::Tile::Frame.new(root) {padding "3 3 12 12"}.grid( :sticky => 'nsew')
TkGrid.columnconfigure root, 0, :weight => 1; TkGrid.rowconfigure root, 0, :weight => 1

$feet = TkVariable.new; $meters = TkVariable.new
f = Tk::Tile::Entry.new(content) {width 7; textvariable $feet}.grid( :column => 2, :row => 1, :sticky => 'we' )
Tk::Tile::Label.new(content) {textvariable $meters}.grid( :column => 2, :row => 2, :sticky => 'we');
Tk::Tile::Button.new(content) {text 'Calculate'; command {calculate}}.grid( :column => 3, :row => 3, :sticky => 'w')

Tk::Tile::Label.new(content) {text 'feet'}.grid( :column => 3, :row => 1, :sticky => 'w')
Tk::Tile::Label.new(content) {text 'is equivalent to'}.grid( :column => 1, :row => 2, :sticky => 'e')
Tk::Tile::Label.new(content) {text 'meters'}.grid( :column => 3, :row => 2, :sticky => 'w')

TkWinfo.children(content).each {|w| TkGrid.configure w, :padx => 5, :pady => 5}
f.focus
root.bind("Return") {calculate}

def calculate
  begin
     $meters.value = (0.3048*$feet*10000.0).round()/10000.0
  rescue
     $meters.value = ''
  end
end

Tk.mainloop

