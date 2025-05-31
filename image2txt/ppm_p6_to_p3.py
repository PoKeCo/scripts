def read_ppm_p6(filename):
    with open(filename, 'rb') as f:
        header = f.readline().strip()
        if header != b'P6':
            raise ValueError("Not a P6 PPM file")

        # Skip comments
        def read_non_comment_line():
            while True:
                line = f.readline()
                if not line.startswith(b'#'):
                    return line

        # Read width, height
        dims = read_non_comment_line().strip().split()
        width, height = map(int, dims)

        # Read max value
        maxval = int(read_non_comment_line().strip())

        # Read binary pixel data
        pixel_data = f.read(width * height * 3)

    return width, height, maxval, pixel_data


def write_ppm_p3(filename, width, height, maxval, pixel_data):
    with open(filename, 'w') as f:
        f.write('P3\n')
        f.write(f'{width} {height}\n')
        f.write(f'{maxval}\n')

        for i in range(0, len(pixel_data), 3):
            r, g, b = pixel_data[i:i+3]
            f.write(f'{r} {g} {b}\n')


if __name__ == '__main__':
    import sys
    if len(sys.argv) != 3:
        print("Usage: python3 ppm_p6_to_p3.py input.ppm output.ppm")
        sys.exit(1)

    width, height, maxval, pixel_data = read_ppm_p6(sys.argv[1])
    write_ppm_p3(sys.argv[2], width, height, maxval, pixel_data)
