# $(shell cat), not $(file < ...). The file function arrived in GNU Make 4.0,
# and macOS still ships 3.81 from 2006 -- which does not report an unknown
# function, it reads $(file < VERSION) as a reference to a variable named
# "file < VERSION", finds nothing, and expands to empty. The release then ran
# `git tag -s` with no tag name.
ver = $(shell cat VERSION)

# Usage: make release name="Proxmox default disk fix"
# Produces a release titled "v0.9.1 Proxmox default disk fix".
# The tag is made with -m so it never opens an editor. Without it, `git tag -s`
# asks for a message interactively and aborts with "no tag message?" and exit
# 128 when the buffer is left empty -- which reads like a signing failure and is
# not one. The tag message matches the release title.
release:
	@[ -n "$(name)" ] || { echo 'name is required, e.g. make release name="Short description"'; exit 1; }
	@[ -n "$(ver)" ] || { echo 'VERSION is empty -- refusing to tag. Check that VERSION exists and that make can read it.'; exit 1; }
	git tag $(ver) -s -m "$(ver) $(name)"
	git push --tags
	git pull
	gh release create $(ver) --title "$(ver) $(name)" --generate-notes
