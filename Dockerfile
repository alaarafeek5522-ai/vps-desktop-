FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ============================================
# 1. التحديث والأدوات الأساسية
# ============================================
RUN apt update -y && apt upgrade -y && \
    apt install --no-install-recommends -y \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server novnc websockify \
    sudo xterm init systemd \
    vim net-tools curl wget git tzdata \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    software-properties-common \
    # أدوات التطوير
    python3 python3-pip python3-venv \
    nodejs npm \
    php php-cli php-mbstring \
    golang-go \
    ruby \
    build-essential cmake \
    htop neofetch screen tmux \
    # أدوات الشبكة
    openssh-server nginx \
    # أدوات إضافية
    firefox-esr chromium-browser \
    libreoffice \
    vlc \
    filezilla \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# 2. إعداد SSH (عشان Termux)
# ============================================
RUN mkdir /var/run/sshd && \
    echo 'root:root123' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# ============================================
# 3. تثبيت Code Server (VS Code في المتصفح)
# ============================================
RUN curl -fsSL https://code-server.dev/install.sh | sh

# ============================================
# 4. Firefox
# ============================================
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    apt update -y && apt install -y firefox

# ============================================
# 5. الثيم والخلفية
# ============================================
RUN apt install -y xubuntu-icon-theme && \
    git clone https://github.com/B00merang-Project/Windows-10.git /usr/share/themes/Windows-10 && \
    git clone https://github.com/B00merang-Project/Windows-10-Icons.git /usr/share/icons/Windows-10 && \
    mkdir -p /etc/xdg/autostart && \
    echo "[Desktop Entry]" > /etc/xdg/autostart/set-win-theme.desktop && \
    echo "Type=Application" >> /etc/xdg/autostart/set-win-theme.desktop && \
    echo "Exec=sh -c \"xfconf-query -c xsettings -p /Net/ThemeName -s Windows-10; xfconf-query -c xsettings -p /Net/IconThemeName -s Windows-10; xfconf-query -c xfwm4 -p /general/theme -s Windows-10\"" >> /etc/xdg/autostart/set-win-theme.desktop && \
    echo "Name=Set Win Theme" >> /etc/xdg/autostart/set-win-theme.desktop

# خلفية مخصصة
RUN mkdir -p /usr/share/backgrounds/xfce /usr/share/xfce4/backdrops && \
    wget --no-check-certificate "https://b.top4top.io/p_3853l6za61.jpg" -O /usr/share/backgrounds/custom.jpg && \
    find /usr/share/backgrounds/ /usr/share/xfce4/backdrops/ -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.svg" \) -exec cp /usr/share/backgrounds/custom.jpg {} \;

# ============================================
# 6. إعداد VNC مع باسورد
# ============================================
RUN mkdir -p /root/.vnc && \
    echo "masa123" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

RUN touch /root/.Xauthority

# ============================================
# 7. noVNC مع SSL
# ============================================
RUN echo '<meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&resize=scale&password=masa123">' > /usr/share/novnc/index.html && \
    echo '<meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&resize=scale&password=masa123">' > /usr/share/novnc/vnc_lite.html

# ============================================
# 8. سكربت التشغيل
# ============================================
RUN echo '#!/bin/bash\n\
# إعداد VNC\n\
vncserver -localhost no -geometry 1920x1080 -depth 24 :1 &\n\
\n\
# تشغيل SSH\n\
/usr/sbin/sshd\n\
\n\
# تشغيل Code Server\n\
code-server --bind-addr 0.0.0.0:8080 --auth password --password masa123 &\n\
\n\
# إنشاء شهادة SSL\n\
openssl req -new -subj "/C=JP" -x509 -days 365 -nodes -out /root/self.pem -keyout /root/self.pem 2>/dev/null\n\
\n\
# تشغيل noVNC\n\
websockify -D --web=/usr/share/novnc/ --cert=/root/self.pem 6080 localhost:5901\n\
\n\
# إبقاء الكونتينر شغال\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

# ============================================
# 9. Ports
# ============================================
EXPOSE 5901
EXPOSE 6080
EXPOSE 8080
EXPOSE 22

CMD ["/start.sh"]
