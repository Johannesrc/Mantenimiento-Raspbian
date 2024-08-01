#!/bin/env bash
# *************************************************************************** #
# @company ... Abstract Zone
# @author .... Johannes Rosenkranz Cordovez (Roco)
# @email ..... jfronz@gmail.com
# *************************************************************************** #
# License:
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# *************************************************************************** #

# Detectar el usuario real antes de ser root
if [ "$SUDO_USER" ]; then
    usuario_del_equipo="$SUDO_USER"
else
    usuario_del_equipo="Usuario del equipo"
fi

# Función de limpieza
Ubucleaner() {
    # Constantes locales.
    OLDCONF=$(dpkg -l | grep "^rc" | awk '{print $2}')
    CURKERNEL=$(uname -r | sed 's/-*[a-z]//g' | sed 's/-386//g')
    LINUXPKG="linux-(image|headers|modules)"
    METALINUXPKG="linux-(image|headers|modules)-(generic|i386|server|common|rt|xen)"
    OLDKERNELS=$(dpkg -l | awk '{print $2}' | grep -E $LINUXPKG | grep -vE $METALINUXPKG | grep -v $CURKERNEL)
    YELLOW="\033[1;33m"
    RED="\033[0;31m"
    ENDCOLOR="\033[0m"

    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: debe ser root${ENDCOLOR}"
        echo -e "${YELLOW}Saliendo...${ENDCOLOR}"
        exit 1
    fi

    echo -e "${YELLOW}Limpiando caché de apt...${ENDCOLOR}"
    apt-get clean

    echo -e "${YELLOW}Eliminando archivos de configuración antiguos...${ENDCOLOR}"
    apt-get -y purge $OLDCONF

    echo -e "${YELLOW}Eliminando kernels antiguos...${ENDCOLOR}"
    apt-get -y purge $OLDKERNELS

    echo -e "${YELLOW}Vaciando todas las papeleras...${ENDCOLOR}"
    rm -rf /home/*/.local/share/Trash/*/** &> /dev/null
    rm -rf /root/.local/share/Trash/*/** &> /dev/null

    echo -e "${YELLOW}¡Script Finalizado!${ENDCOLOR}"
}

Main() {
    echo "Hola $usuario_del_equipo"
    echo "Vamos a iniciar con el mantenimiento del equipo"
    sleep 0.5

    echo -e "1. Actualizando la lista de paquetes..."
    apt-get update -qq

    echo -e "2. Actualizando el sistema..."
    apt-get -y upgrade
    apt-get -y dist-upgrade

    echo -e "3. Checando dependencias incumplidas..."
    apt-get check -qq

    echo -e "4. Corrigiendo dependencias incumplidas..."
    apt-get install -fy -qq

    echo -e "5. Desinstalando paquetes en desuso..."
    apt-get -y autoremove

    echo -e "6. Borrando archivos descargados..."
    apt-get autoclean -qq

    echo -e "7. Borrando archivos antiguos descargados..."
    apt-get clean -qq

    # GRUB no es necesario en Raspbian, así que omitimos la limpieza del menú de GRUB
    # echo -e "8. Limpiando el menú de GRUB..."
    # update-grub2

    for ((i = 1; i <= 2; i++)); do
        echo -e "8. Eliminando paquetes de datos innecesarios (Ciclo $i)..."
        deborphan --guess-all | xargs -r apt-get -y purge
        echo -e "9. Eliminando bibliotecas innecesarias (Ciclo $i)..."
        deborphan | xargs -r apt-get -y remove --purge
    done

    Ubucleaner
    apt-get -y autoremove
    ldconfig

    echo "Listo $usuario_del_equipo, terminamos con el mantenimiento del equipo"
    echo "Hasta luego"
    sleep 0.1
}

Main
# *************************************************************************** #
