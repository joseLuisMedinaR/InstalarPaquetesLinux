#!/bin/bash
# Vamos a preguntar al usuario si desea instalar un conjunto de paquetes
# $1= nombre del conjunto de paquetes

ask_installation() {
    read -p "¿Desea instalar $1? (S/N): " answer
    if [ "$answer" != "${answer#[Ss]}" ]; then
        return 0
    else
        return 1
    fi
}

# Determinar el gestor de paquetes
if [ -x "$(command -v dnf)" ]; then
    PKG_MANAGER="dnf install -y"
    UPDATE_CMD="sudo dnf update -y"
elif [ -x "$(command -v apt)" ]; then
    PKG_MANAGER="apt install -y"
    UPDATE_CMD="sudo apt update && sudo apt upgrade -y"
elif [ -x "$(command -v pacman)" ]; then
    PKG_MANAGER="pacman -S --noconfirm --needed"
    UPDATE_CMD="sudo pacman -Syu --noconfirm"
else
    echo "No se pudo determinar el gestor de paquetes."
    exit 1
fi

# Actualizar sistema
echo "Vamos a Instalar todo lo necesario para tener listo el S.O."
echo "Detectado gestor de paquetes: $PKG_MANAGER"
echo "Ejecutando actualización del sistema..."
$UPDATE_CMD

# Instalar repositorios RPMFUSION si es Fedora
if [ "$PKG_MANAGER" == "dnf install -y" ]; then
    echo "Instalando los repositorios de RPMFUSION..."
    sudo $PKG_MANAGER \
      https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
      https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm  
    sudo $PKG_MANAGER group update core
fi

# Agregar Flathub
echo "Agregando Flathub..."
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Instalar Snap
echo "Instalando Snap..."
sudo $PKG_MANAGER snapd
sudo ln -s /var/lib/snapd/snap /snap
sudo snap install snap-store

# Instalar drivers de impresora Brother HL1200
if ask_installation "los drivers de la impresora Brother HL1200"; then
    echo "Instalando los drivers de la impresora Brother HL1200..."
    sudo $PKG_MANAGER printer-driver-brlaser
fi
# Fin de los drivers de impresora Brother HL1200

# Instalar códecs, compresores y utilidades multimedia
echo "Instalando códecs, compresores y utilidades multimedia..."
sudo $PKG_MANAGER \
  gstreamer1-libav \
  gstreamer1-plugins-{base,good,good-extras,bad-free,bad-free-extras,ugly} \
  libdvdread libdvdnav lsdvd \
  unrar p7zip p7zip-plugins \
  mscore-fonts-all \
  ffmpeg ffmpeg-devel \
  lame

# Instalar paquetes multimedia adicionales si es Fedora
if [ "$PKG_MANAGER" == "dnf install -y" ]; then
    sudo $PKG_MANAGER gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly
fi

# Configurar contraseña para usuario root
echo "Vamos a configurar la contraseña para el usuario root..."
sudo passwd root

# Instalar aplicaciones adicionales
if ask_installation "aplicaciones adicionales"; then
    echo "Instalando aplicaciones adicionales..."
    APPS=(
        "neofetch"
        "nmap"
        "htop"
        "gnome-terminal"
        "telegram-desktop"
        "audacity"
        "inkscape"
        "krita"
        "gimp"
        "darktable"
        "vlc"
        "kdenlive"
        "remmina"
        "keepassxc"
        "gnome-tweak-tool"
    )
    for app in "${APPS[@]}"; do
        sudo $PKG_MANAGER "$app"
    done
fi
# Fin de aplicaciones adicionales

# Instalar herramientas para desarrollo
if ask_installation "las herramientas para desarrollo"; then
    echo "Instalando herramientas para desarrollo..."
    sudo $PKG_MANAGER \
        python3-pip \
        python3-tkinter \
        git php phpMyAdmin nginx community-mysql-server filezilla \
        libnsl mod_perl libaio libxcrypt-compat
    sudo pip3 install pyinstaller pytube plyer
    sudo pip install virtualenv tqdm

# Workbench (es para aprender y crear prototipos con tecnologías GNOME)
    flatpak install flathub re.sonny.Workbench

# Postman
    flatpak install flathub com.getpostman.Postman

# Instalar DBeaver Community (manejo de base de datos)
    sudo snap install dbeaver-ce

# Playhouse (igual que Workbench pero lo comento por que no está recibiendo actualizaciones)
#flatpak install flathub re.sonny.Playhouse

# Configurar MySQL
echo "Ahora vamos a configurar MySQL, prestá atención a las siguientes preguntas:..."
sudo mysql_secure_installation
fi

# Fin de las herramientas para desarrollo

# Mostramos mensaje de finalización
echo "Instalación finalizada. Recuerda agregar los programas adicionales de tu interés."
echo "JoseLu Web Soluciones Informáticas"