all: build

build:
	@docker build --tag=aarospl/bind .
