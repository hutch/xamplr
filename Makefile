
check:
	git clean -dx --dry-run

clean:
	git clean -fdx
	ln -s ../dot.idea .idea

release:
	rake version:bump:patch release

stalk:
	gemstalk hutch xamplr
