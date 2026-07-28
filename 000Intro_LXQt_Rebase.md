# Install Fedora CoreOS on VPS

```
# 使用上传完毕的fedora-coreos-44.20260621.3.1-openstack.x86_64.qcow2，安装失败
# 使用官方的LiveISO，安装成功
```


# Rebase to uCore

```
# rebase到uCore，出错
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/ublue-os/ucore:stable  
```

# Rebase to my LXQt blue-build-image

```
# 从Fedora CoreOS直接rebase到自定义镜像，出错
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/edwardwoodhub/my-lxqt-qcow2:latest
```

# 总结
以上这种rebase的安装blue-build-image的方式，失败了。后来发现，直接使用bluefin的iso（本身即是live镜像），直接在VNC中就可以图形化安装。
