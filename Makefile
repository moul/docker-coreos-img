CHANNEL ?=	stable
VERSION ?=	899.13.0
REPO ?=		moul/coreos-img

PXE_IMG_URL =	http://${CHANNEL}.release.core-os.net/amd64-usr/${VERSION}/coreos_production_pxe_image.cpio.gz
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


$(NAME)-rootfs: $(NAME)-pxe-image
	rm -rf $@ $@.tmp
	unsquashfs -f -d $@.tmp $(NAME)-pxe-image/usr.squashfs
	mv $@.tmp $@
	touch $@


$(NAME)-pxe-image: $(NAME)-pxe-image.cpio
	rm -rf $@ $@.tmp
	mkdir -p $@.tmp
	cd $@.tmp && cpio -idv < ../$(NAME)-pxe-image.cpio
	mv $@.tmp $@


$(NAME)-pxe-image.cpio:
	wget -O $@.gz $(PXE_IMG_URL)
	gunzip $@.gz
