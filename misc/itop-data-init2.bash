#!/bin/bash

# itop-data-init2.bash : initialize the /itop folder, link the folders

# I'm too lazy to thanslate that whole explanation !
# L'idée de départ :
#    • La distro complète iTop va dans le container, dans le dossier /itopsrc. 
#      Owner root:root, droits 444 pour les fichiers et 555 pour les directories (ça, on le fait au moment du build)
#    • Au build, on crée un fichier témoin /build.manifest qui contient la date et l'heure du build. 
#      ( date "+%Y-%m-%d--%H-%M-%S" )
#    • On monte un persistent volume en /itop,
#    • Au boot de la machine, si /itop/build.manifest est différent de /manifest, alors : 
#        avant de lancer Apache, 
#        - on supprime tous les liens symboliques dans /itop, 
#        - on 'chown -R www-data:www-data /itop, 
#        - chmod -R 0755 /itop, 
#        - puis on ln -s tout ce qui est dans /itopsrc dans /itop 
#        - puis on copie /build.manifest dans /itop (ceci permet de gérer un changement de version)
#
# systématiquement on (re)crée les liens de itop ver itopsrc
#
# Cas particuliers des dossiers /data et /log qui doivent être dans /itop en rw mais doivent contenir des fichiers depuis la source...

SRC='/itopsrc'
DEST='/itop'
MANIFEST='/build.manifest'
OWNER='www-data:www-data'

# Action needed ? Yes if /itop/build.manifest (in the persistent storage) is missing or different of 
# the file /build.manifest (in the container's image)

if ! cmp -s $MANIFEST $DEST$MANIFEST
then 
    # Should never be usefull
    mkdir -p $DEST
    # specific action for /data and /log folders
    if [ ! -d $DEST/data ]
    then
        cp -r $SRC/datasrc $DEST/data
    fi
    if [ ! -d $DEST/log ]
    then
        cp -r $SRC/logsrc $DEST/log
    fi
    # suppress all symbolic links in /itop folder
    find $DEST -maxdepth 1 -type l -exec rm {} \;
    # creating empty folder, if needed
    [ -d $DEST/conf ] || mkdir -p $DEST/conf
    [ -d $DEST/env-production ] || mkdir -p $DEST/env-production
    [ -d $DEST/env-production-build ] || mkdir -p $DEST/env-production-build
    # security fix 
    chown -R "$OWNER" $DEST
    chmod -R  0640 $DEST 
    find $DEST -type d -exec chmod 0750 {} \;
    # create symbolic links in itopsrc folder
    find $SRC -maxdepth 1 -path '*/data' -prune -o -path '*/log' -prune -o -exec ln -s {} $DEST \;
    # update the timestamp
    cp -f $MANIFEST $DEST$MANIFEST
fi

# Some links are rebuild at each container start. Safety measure :)
rm -f $SRC/data                 ; ln -s $DEST/data $SRC
rm -f $SRC/log                  ; ln -s $DEST/log $SRC
rm -f $SRC/conf                 ; ln -s $DEST/conf $SRC
rm -f $SRC/env-production       ; ln -s $DEST/env-production $SRC
rm -f $SRC/env-production-build ; ln -s $DEST/env-production-build $SRC

# Initialization ened, time to start the Apache server
# This line is the normal cmd in the php-apache Container
exec apache2-foreground
