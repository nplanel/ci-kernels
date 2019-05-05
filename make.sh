#!/bin/bash

set -eu
set -o pipefail

readonly script_dir="$(cd $(dirname "$0"); pwd)"
readonly build_dir="${script_dir}/build"

mkdir -p "${build_dir}"

readonly kernel_versions=("4.19.40" "5.0.13")
for kernel_version in "${kernel_versions[@]}"; do
	if [[ -f "linux-${kernel_version}.bz" ]]; then
		echo Skipping ${kernel_version}, it already exist
		continue
	fi

	readonly src_dir="${build_dir}/linux-${kernel_version}"
	readonly archive="${build_dir}/linux-${kernel_version}.tar.xz"

	test -e "${archive}" || curl --fail -L https://cdn.kernel.org/pub/linux/kernel/v${kernel_version%%.*}.x/linux-${kernel_version}.tar.xz -o "${archive}"
	test -d "${src_dir}" || tar --xz -xf "${archive}" -C "${build_dir}"

	pushd "${src_dir}"
	make KCONFIG_CONFIG=custom.config defconfig
	cat "${script_dir}/config" >> "${src_dir}/custom.config"
	make allnoconfig KCONFIG_ALLCONFIG="custom.config"
	virtme-configkernel --update

	make clean
	make -j$(nproc) bzImage

	mv "arch/x86/boot/bzImage" "${script_dir}/linux-${kernel_version}.bz"
	popd
done


