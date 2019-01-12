.PHONY: test
test:
	bundle exec rake test

.PHONY:
install:
	bundle install --path=vendor/bundle -j4


.PHONY: release
release:
	bundle exec rake release

