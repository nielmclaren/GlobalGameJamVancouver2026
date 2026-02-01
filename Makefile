export:
	rm -rf bin/web
	mkdir -p bin/web
	touch bin/.gdignore
	godot --headless --export-debug "Web" bin/web/index.html

publish:
	butler push bin/web nielmclaren/sneaky-elementals:web

status:
	butler status nielmclaren/sneaky-elementals:web

release-linux:
	rm -rf bin/linux
	mkdir -p bin/linux
	touch bin/.gdignore
	godot --headless --export-release "Linux" bin/linux/sneaky_elementals.x86_64
	butler push bin/linux nielmclaren/sneaky-elementals:linux

release-windows:
	rm -rf bin/windows
	mkdir -p bin/windows
	touch bin/.gdignore
	godot --headless --export-release "Windows Desktop" bin/windows/sneaky_elementals.exe
	butler push bin/windows nielmclaren/sneaky-elementals:windows

release-osx:
	rm -rf bin/osx
	mkdir -p bin/osx
	touch bin/.gdignore
	godot --headless --export-release "macOS" bin/osx/sneaky_elementals.app
	butler push bin/osx nielmclaren/sneaky-elementals:osx
