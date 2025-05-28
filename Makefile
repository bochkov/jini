all:
	cmake -DJNI_INCLUDE_PATH="$(JNI)" -DCMAKE_BUILD_TYPE="Release" -G "MinGW Makefiles" -B cmake-build-release -S .
	make -C cmake-build-release
	nim cpp --nimcache=cmake-build-release/nim/gui -w:on --app:gui     -d:release --opt:size \
	 --dynlibOverride:libjini --passL:"-static -L.\cmake-build-release -l:libjini.a -s" \
	 --out:cmake-build-release/jini.exe     src/app/main.nim
	nim cpp --nimcache=cmake-build-release/nim/cli -w:on --app:console -d:release --opt:size \
	 --dynlibOverride:libjini --passL:"-static -L.\cmake-build-release -l:libjini.a -s" \
	 --out:cmake-build-release/jini-cli.exe src/app/main.nim

clean:
	@rm -rf cmake-*
