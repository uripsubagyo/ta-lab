def main():
    array_list = [23,11,10]
    temp = []
    array_list.sort(reverse=False)

    while len(array_list) > 0:
        if len(array_list) == 1:
            temp.append(array_list.pop())
            break
        else:
            temp.append(array_list.pop() + array_list.pop())

    print(temp)
if __name__ == "__main__":
    main()



