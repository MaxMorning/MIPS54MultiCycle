import os

hex_path = r"G:\FTP\TransTemp\MIPS54\HEX"
cpu_res_path = r"G:\FTP\TransTemp\MIPS54\RES"
mars_res_path = r"G:\FTP\TransTemp\MIPS54\MARSRES"
workspace_path = r"G:\FTP\TransTemp\MIPS54\WORKSPACE"
work_path = r"E:\digital\Project\MIPS54MultiCycle\verilog"

def conv_8(file_path):
    with open(file_path, 'r') as file_32:
        cont_32 = file_32.readlines()

        files = []
        for i in range(4):
            files.append(open(file_path[:-4] + '_' + str(i) + ".txt", 'w'))

        for line_idx in range(0, len(cont_32)):
            for i in range(4):
                files[i].write(cont_32[line_idx][6 - 2 * i: 6 - 2 * i + 2] + '\n')

        for file_8 in files:
            file_8.close()


if __name__ == '__main__':
    os.chdir(work_path)
    # compile
    os.system(r'vlog "ALU.v"')
    os.system(r'vlog "branchCalc.v"')
    os.system(r'vlog "clzCalculate.v"')
    os.system(r'vlog "Concatenate.v"')
    os.system(r'vlog "Controller.v"')
    os.system(r'vlog "CP0.v"')
    os.system(r'vlog "divCalculate.v"')
    os.system(r'vlog "Hi_reg.v"')
    os.system(r'vlog "Lo_reg.v"')
    os.system(r'vlog "mem8.v"')
    os.system(r'vlog "RAM8.v"')
    os.system(r'vlog "RAM.v"')
    os.system(r'vlog "ImmExt.v"')
    os.system(r'vlog "PC.v"')
    os.system(r'vlog "fake_pc.v"')
    os.system(r'vlog "RegFile.v"')
    os.system(r'vlog "IR.v"')
    os.system(r'vlog "multCalculate.v"')
    os.system(r'vlog "CPU.v"')
    os.system(r'vlog "sccomp_dataflow.v"')
    os.system(r'vlog "./tb/soc_tb.v"')

    print("Compile Done!")
    file_names = os.listdir(hex_path)
    print(file_names)
    is_wrong = False
    for file_name in file_names:
        if file_name[-4:] == ".txt":
            print("Start Simulation in ", file_name)
            # copy instr
            with open(os.path.join(hex_path, file_name), 'r') as file_src:
                with open(os.path.join(workspace_path, "ram.txt"), 'w') as file_dst:
                    file_content = file_src.read()
                    file_dst.write(file_content)
                    for i in range(256):
                        file_dst.write("00000000\n")

                conv_8(os.path.join(workspace_path, "ram.txt"))

            # start simulation
            os.system(r'vsim -c -t 1ps -lib work soc_tb -do "run 7000ns;quit -sim;quit;"')
            # os.system(r'quit -sim')
            # os.system(r'quit')

            # compare
            # is_wrong = false
            with open(os.path.join(workspace_path, "result.txt"), 'r') as file_result:
                with open(os.path.join(mars_res_path, file_name[:-8] + ".result.txt"), 'r') as file_standard:
                    result = file_result.read()
                    standard = file_standard.read()

                    result = result.replace(' ', '')
                    result = result.replace('\n', '')

                    standard = standard.replace(' ', '')
                    standard = standard.replace('\n', '')

                    index = 0
                    min_index = min(len(standard), len(result))
                    while index < min_index:
                        # if standard[index] == 'p':
                        #     index += 12
                        #     continue

                        if standard[index] != result[index]:
                            print(file_name, " Wrong!")
                            is_wrong = True
                            break

                        index += 1

            if is_wrong:
                break

    if not is_wrong:
        print("Congratulations!")
