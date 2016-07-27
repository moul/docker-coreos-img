CHANNEL ?=	stable
VERSION ?=	1068.8.0
REPO ?=		moul/coreos-img

PXE_IMG_URL =	http://${CHANNEL}.release.core-os.net/amd64-usr/${VERSION}/coreos_production_pxe_image.cpio.gz
BIN_IMG_URL =	http://${CHANNEL}.release.core-os.net/amd64-usr/${VERSION}/coreos_production_image.bin.bz2
NAME =		$(CHANNEL)-$(VERSION)
BUILD_DATE =	$(shell date "+%Y-%m-%d")


all: build


.PHONY: build
build: $(NAME).docker-image


.PHONY: shell
shell: build
	docker run -it --rm $(REPO):$(NAME)


.PHONY: release
release: build
	docker push $(REPO)


$(NAME).docker-image: $(NAME)-rootfs.tar
	docker import \
	  -c "ENV ARCH=x86_64 COREOS_CHANNEL=$(CHANNEL) COREOS_VERSION=$(VERSION) PXE_IMAGE_URL=$(PXE_IMG_URL) BUILD_DATE=$(BUILD_DATE)" \
	  -c 'CMD ["/bin/bash"]' \
	  -m "hello :)" \
	  $(NAME)-rootfs.tar $(REPO):$(NAME)
	docker run --rm $(REPO):$(NAME) echo "Success"
	docker tag -f $(REPO):$(NAME) $(REPO):$(VERSION)
	touch $@


$(NAME)-rootfs.tar: $(NAME)-rootfs
	cd $(NAME)-rootfs && tar cf ../$@ .


$(NAME)-rootfs: $(NAME)-image.bin
	./rootfs.sh $(NAME)


$(NAME)-image.bin:
	wget -O $@.bz2 $(BIN_IMG_URL)
	bunzip2 $@.bz2

clean:
	umount $(NAME)-rootfs/usr || true
	umount $(NAME)-rootfs || true
	rm -rf $(NAME)-image.bin
	rm -rf $(NAME)-rootfs.tar
	rm -rf $(NAME)-rootfs
	rm -rf $(NAME).docker-image
