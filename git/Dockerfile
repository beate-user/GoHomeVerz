from alpine/git:latest
run apk update \
	&& apk add zsh vim wget curl tmux tig\
	&& sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

# docker run -ti --rm --entrypoint /bin/zsh  -u$(id -u):$(id -g) -e HOME=${HOME} -v /etc/passwd:/etc/passwd -v /etc/group:/etc/group -v ${HOME}:${HOME} -v $(pwd):/git $(docker build -q git)
