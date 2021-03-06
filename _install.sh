trap 'exit $?' ERR
log () { 
    printf "%s\t***\t%s\n" "$(date +[%FT%T%:z])" "$1" 
} 

DIR=$1
export ROLE=$2
receipt=$3
export ALTAI_LOG=$4

cat  >$DIR/solo.rb <<EOF
file_cache_path "$DIR"
cookbook_path "$DIR/cookbooks"
role_path "$DIR/roles"
EOF

#export GIT=`git log --format=%H -n 1`
#log "Altai release"
#git log -n 1

log "run cookbook"
export GEM_HOME="/opt/altai-chef-gems/"
export GEM_PATH="${GEM_HOME}:"
/opt/altai-chef-gems/bin/chef-solo -c solo.rb -j "$receipt" -N "$ROLE"
