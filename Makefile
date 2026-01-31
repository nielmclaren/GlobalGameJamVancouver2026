export:
	rm -rf bin/web
	mkdir -p bin/web
	touch bin/.gdignore
	godot --headless --export-debug "Web" bin/web/index.html

publish:
	butler push bin/web nielmclaren/ggjvancouver:web

status:
	butler status nielmclaren/ggjvancouver:web

release-linux:
	rm -rf bin/linux
	mkdir -p bin/linux
	touch bin/.gdignore
	godot --headless --export-release "Linux" bin/linux/ggjvancouver.x86_64
	butler push bin/linux nielmclaren/ggjvancouver:linux

release-windows:
	rm -rf bin/windows
	mkdir -p bin/windows
	touch bin/.gdignore
	godot --headless --export-release "Windows Desktop" bin/windows/ggjvancouver.exe
	butler push bin/windows nielmclaren/ggjvancouver:windows

release-osx:
	rm -rf bin/osx
	mkdir -p bin/osx
	touch bin/.gdignore
	godot --headless --export-release "macOS" bin/osx/ggjvancouver.app
	butler push bin/osx nielmclaren/ggjvancouver:osx
