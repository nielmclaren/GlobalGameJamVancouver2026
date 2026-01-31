export:
	rm -rf bin/web
	mkdir -p bin/web
	touch bin/.gdignore
	godot --headless --export-debug "Web" bin/web/index.html

publish:
	butler push bin/web nielmclaren/vggj2026:web

status:
	butler status nielmclaren/vggj2026:web

release-linux:
	rm -rf bin/linux
	mkdir -p bin/linux
	touch bin/.gdignore
	godot --headless --export-release "Linux" bin/linux/vggj2026.x86_64
	butler push bin/linux nielmclaren/vggj2026:linux

release-windows:
	rm -rf bin/windows
	mkdir -p bin/windows
	touch bin/.gdignore
	godot --headless --export-release "Windows Desktop" bin/windows/vggj2026.exe
	butler push bin/windows nielmclaren/vggj2026:windows

release-osx:
	rm -rf bin/osx
	mkdir -p bin/osx
	touch bin/.gdignore
	godot --headless --export-release "macOS" bin/osx/vggj2026.app
	butler push bin/osx nielmclaren/vggj2026:osx
