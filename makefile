ver = $(file < VERSION)

# Usage: make release name="Proxmox default disk fix"
# Produces a release titled "v0.9.1 Proxmox default disk fix".
release:
	@[ -n "$(name)" ] || { echo 'name is required, e.g. make release name="Short description"'; exit 1; }
	git tag $(ver) -s
	git push --tags
	git pull
	gh release create $(ver) --title "$(ver) $(name)" --generate-notes
