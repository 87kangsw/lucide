SCRIPT=./scripts/generate_assets.sh

# 최초 한 번 실행할 chmod 타겟
.PHONY: setup
setup:
	chmod +x $(SCRIPT)

# 실제 실행용 타겟
.PHONY: generate
generate:
	./$(SCRIPT)
