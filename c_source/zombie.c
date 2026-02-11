#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main() {
    int pid = fork();

    if (pid > 0) {
        // Родительский процесс: спит 60 секунд, не вызывая wait()
        printf("Родительский процесс (PID: %d) спит 60 секунд...\n", getpid());
        sleep(60);
    } else if (pid == 0) {
        // Дочерний процесс: завершает работу
        printf("Дочерний процесс (PID: %d) завершается.\n", getpid());
        exit(0);
    } else {
        // Ошибка при создании дочернего процесса
        printf("Ошибка: не удалось создать дочерний процесс.\n");
        return 1;
    }

    return 0;
}
