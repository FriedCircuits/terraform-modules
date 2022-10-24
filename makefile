ver = $(file < VERSION)

release:
	git tag $(ver) -s
	git push --tags
	git pull
	gh release create $(ver)
