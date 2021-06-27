import os

if __name__ == '__main__':
    file_path = input()
    with open(file_path, 'r') as file_32:
        cont_32 = file_32.readlines()

        files = []
        for i in range(4):
            files.append(open(file_path[:-4] + '_' + str(i) + ".coe", 'w'))

        start_idx = 0
        if cont_32[0][0] == 'm':
            start_idx = 2
            for file_8 in files:
                file_8.write(cont_32[0])
                file_8.write(cont_32[1])

        for line_idx in range(start_idx, len(cont_32)):
            for i in range(4):
                files[i].write(cont_32[line_idx][6 - 2 * i: 6 - 2 * i + 2] + '\n')

        for file_8 in files:
            file_8.close()
