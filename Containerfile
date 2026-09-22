# 切回 uBlue 基础底座
FROM ghcr.io/ublue-os/base-main:44

# 1. 使用 dnf5 安装桌面环境及所需软件包
RUN dnf5 -y install --setopt=install_weak_deps=False \
    adwaita-cursor-theme \
    adwaita-icon-theme \
    atril \
    btop \
    dbus-x11 \
    engrampa \
    fastfetch \
    featherpad \
    flameshot \
    firewalld \
    galculator \
    gedit \
    git \
    gnome-terminal \
    grim \
    hicolor-icon-theme \
    htop \
    labwc \
    lximage-qt \
    lxqt-themes \
    lxqt-themes-fedora \
    lxqt-about \
    lxqt-config \
    lxqt-globalkeys \
    lxqt-notificationd \
    lxqt-openssh-askpass \
    lxqt-panel \
    lxqt-policykit \
    lxqt-qtplugin \
    lxqt-runner \
    lxqt-session \
    lxqt-wayland-session \
    lxqt-labwc-session \
    meld \
    mesa-dri-drivers \
    polkit \
    pcmanfm-qt \
    pluma \
    qterminal \
    screengrab \
    sddm \
    slurp \
    spectacle \
    thunar \
    thunar-archive-plugin \
    tilix \
    wayvnc \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-wlr \
    xdg-user-dirs \
    xdg-desktop-portal \
    xorg-x11-drv-vmware \
    xorg-x11-server-Xwayland \
    && dnf5 clean all

# 2. 预置系统 Flatpak 列表 (使用安全单层 printf 写入)
RUN mkdir -p /etc/flatpak/system-flatpaks.d && \
    printf "%s\n" \
      "com.google.Chrome" \
      "com.visualstudio.code" \
      "com.dropbox.Client" \
      "com.github.tchx84.Flatseal" \
      "org.mozilla.firefox" \
      "io.missioncenter.MissionCenter" \
      "com.jianguoyun.Nutstore" \
      "io.github.peazip.PeaZip" \
      "net.nokyan.Resources" \
      "com.xnview.XnViewMP" \
      > /etc/flatpak/system-flatpaks.d/custom-flatpaks.list

# 3. 环境变量、用户 Linger 与防火墙放行
RUN echo "WLR_NO_HARDWARE_CURSORS=1" >> /etc/environment && \
    echo "XDG_CURRENT_DESKTOP=LXQt:labwc:wlroots" >> /etc/environment && \
    echo "XDG_SESSION_TYPE=wayland" >> /etc/environment && \
    mkdir -p /var/lib/systemd/linger && \
    touch /var/lib/systemd/linger/edward && \
    touch /var/lib/systemd/linger/bob && \
    firewall-offline-cmd --add-port=5900/tcp

# 4. 注入 Systemd 服务单元
# 4.1 系统级连接数限制服务
RUN printf "%s\n" \
    "[Unit]" \
    "Description=Limit VNC concurrent connections" \
    "After=firewalld.service network.target" \
    "" \
    "[Service]" \
    "Type=oneshot" \
    "ExecStart=/usr/sbin/iptables -I INPUT -p tcp --dport 5900 -m connlimit --connlimit-above 1 -j REJECT" \
    "RemainAfterExit=yes" \
    "" \
    "[Install]" \
    "WantedBy=multi-user.target" \
    > /etc/systemd/system/vnc-limit.service

# 4.2 用户级 WayVNC 自动拉起服务
RUN mkdir -p /usr/lib/systemd/user && \
    printf "%s\n" \
    "[Unit]" \
    "Description=WayVNC Service" \
    "After=wayland-session.target" \
    "" \
    "[Service]" \
    "Type=simple" \
    "Environment=WAYLAND_DISPLAY=wayland-0" \
    "Environment=XDG_RUNTIME_DIR=%t" \
    "ExecStartPre=/usr/bin/systemctl --user import-environment WAYLAND_DISPLAY XDG_RUNTIME_DIR" \
    "ExecStart=/usr/bin/wayvnc --render-cursor 0.0.0.0 5900" \
    "Restart=always" \
    "RestartSec=10" \
    "" \
    "[Install]" \
    "WantedBy=default.target" \
    > /usr/lib/systemd/user/wayvnc.service

# 5. 启用系统级与用户级服务
RUN systemctl enable sddm.service firewalld.service vnc-limit.service && \
    systemctl --global enable wayvnc.service

# 6. bootc 容器标识
LABEL "containers.bootc"="1"
