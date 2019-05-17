import glob
import re
import collections

class log_message:
    _data = ""
    _id = ""
    _from = ""
    _message = ""

    def __init__(self,message):
        m = message.split(" ", 4)
        if len(m) > 3:
            self._data = m[0] + " " + m[1]
            self._id = m[2]
            self._from = m[3]
            self._message= m[4]

    def printOut(self):
        print(self._data)
        print(self._id)
        print(self._from)
        print(self._message)
        print

class fst:
    _line = -1
    _preState = -1
    _nextState = -1
    _message = ""

    def __init__(self, message):
        m = re.match(r'Status: \[main:([0-9]+)\] "(.+) "' , message)
        if m:
            self._line = m.group(1)
            s = m.group(2).split(" ", 2)
            self._preState = s[0]
            self._nextState = s[1]
            self._message = s[2]

    def printOut(self):
        print("line = " + str(self._line))
        print("state = " + str(self._preState) + "->" + str(self._nextState))
        print("message = " + self._message)
        print()

class state:
    _num = 0
    _useNum = 1
    _escapeNum = 0
    _stayTime = 0
    _recogWordList = []

    def __init__(self, num):
        self._num = int(num)
        self._useNum = 1
        self._recogWordList = []

class stateList:
    _states = []
    _fileNum = 0

    def __init__(self):
        _states = []

    def addState(self, state, stateTime):
        #state existed
        for s in self._states:
            if s._num == state._num:
                s._useNum = s._useNum + 1
                s._stayTime = s._stayTime + stateTime
                return
        #state not existed
        state._stayTime = stateTime
        self._states.append(state)

    def addRecogEvent(self, stateNum, word):
        for s in self._states:
            if s._num == stateNum:
                if word != "<eps>":
                    for w in word.split(","):
                        s._recogWordList.append(w)
                return
    
    def incrementEscapeCnt(self, stateNum):
        for s in self._states:
            if s._num == stateNum:
                s._escapeNum += 1
                return

    def sort(self):
        self._states = sorted(self._states, key=lambda t: t._num)

    def printOut(self):
        for s in self._states:
            print("StateNum: " + str(s._num))
            print("UseCount: " + str(s._useNum / self._fileNum) +
                  " | escapeCount: " + str(s._escapeNum / self._fileNum ))
            print("StayTime: " + str(s._stayTime / s._useNum))
            l_unique = list(set(s._recogWordList))
            for l in l_unique:
                print(l + " " + str(s._recogWordList.count(l)))
            print("--")

    def printFile(self):
        f = open("./MMDAgent.profile", "w", encoding="utf-8")
        
        for s in self._states:
            f.write("StateNum: " + str(s._num) + "\n")
            f.write("UseCount: " + str(s._useNum / self._fileNum) +
                    " | escapeCount: " + str(s._escapeNum / self._fileNum))
            f.write(" | StayTime: " + str(s._stayTime / s._useNum) + "\n")
            l_unique = list(set(s._recogWordList))
            for l in l_unique:
                f.write(l + " " + str(s._recogWordList.count(l)) + "\n")
            f.write("--" + "\n")
        f.close()

if __name__ == '__main__':

    myStateList = stateList()

    files = glob.glob('./*.txt')

    myStateList._fileNum = len(files)

    for f in files:
        print('Processed ' + f )

        data = open(f, encoding='UTF-8').read().split('\n')
        _stateNow = 0

        preM = -1
        preS = -1
        duration = 0

        for i in range(len(data)-1):
            t = log_message(data[i])

            if t._message != "" and t._message.split()[0] == "Status:":

                l = re.match(
                    r'\[[0-9]+/[0-9]+/[0-9]+ [0-9]+:([0-9]+):([0-9]+).[0-9]+]', t._data)
                if _stateNow != 0 and preM != -1 and preS != -1 and l:
                    duration = (int(l.group(1))-preM) * 60 + int(l.group(2)) - preS
                if l:
                    preM = int(l.group(1))
                    preS = int(l.group(2))

                f = fst(t._message)
                if f._nextState != -1:
                    _stateNow = int(f._nextState)
                    myStateList.addState(state(f._nextState), duration)

            elif t._message != "" and t._message.split()[0] == "Captured:" and t._from == "Julius:":
                #print(t._message)
                m = re.match(r'Captured: RECOG_EVENT_STOP\|(.+)' , t._message)
                if m:
                    #print(_stateNow)
                    #print(m.group(1))
                    myStateList.addRecogEvent(_stateNow, m.group(1))
        #escape state
        myStateList.incrementEscapeCnt(_stateNow)

    myStateList.sort()
    print()
    myStateList.printOut()
    myStateList.printFile()
