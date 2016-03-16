import sys, getopt

def parse(inputfile, outputfile):
    file = open(inputfile, 'r')
    data = file.read().split('\n')
    print "ok"
    for line in data:
        print "ok1"
        print line


def main(argv):
    inputfile = ''
    outputfile = ''
    try:
        opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
    except getopt.GetoptError:
        print 'test.py -i <inputfile> -o <outputfile>'
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print 'test.py -i <inputfile> -o <outputfile>'
            sys.exit()
        elif opt in ("-i", "--ifile"):
            inputfile = arg
        elif opt in ("-o", "--ofile"):
            outputfile = arg
    parse(inputfile, outputfile)

if __name__ == "__main__":
    main(sys.argv[1:])
