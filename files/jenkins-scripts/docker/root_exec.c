#include <unistd.h>
#include <stdio.h>
#include <errno.h>

int main(int argc, char **argv) {
	if (argc < 2) {
		fprintf(stderr, "Syntax: %s <program> [arguments]\n", argv[0]);
		return 1;
	}
	setuid(0); setgid(0);
	if (execvp(argv[1], argv + 1) == -1) {
		perror("root_exec: execvp failed");
		return 1;
	}
}
