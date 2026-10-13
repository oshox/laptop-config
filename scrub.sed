# Applied by capture.sh to every text file; install.sh reverses the @...@ placeholders.
s#/var/home/oshox#@HOME@#g
s#/home/oshox#@HOME@#g
s#70933298+oshox@users\.noreply\.github\.com#@GIT_EMAIL@#g
s#^\([[:space:]]*name = \)oshox$#\1@GIT_NAME@#
s#oshox#@USER@#g
s#--location '[^']*'#--location '@WTTR_LOCATION@'#g
