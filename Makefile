
check:
	git clean -dx --dry-run

clean:
	git clean -fdx

release:
	rake version:bump:patch release
