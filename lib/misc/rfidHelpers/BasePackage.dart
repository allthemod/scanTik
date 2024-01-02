class BasePackage
{
}

class ReceiveData
{
    int cmd;
    List<int> data;
    int length;
    String communicationMode;

    ReceiveData(this.cmd, this.length, this.data, this.communicationMode);


    int getCmd()
    {
        return cmd;
    }

    void setCmd(int cmd)
    {
        this.cmd = cmd;
    }

    List<int> getData()
    {
        return data;
    }

    void setData(List<int> data)
    {
        this.data = data;
    }

    int getLength()
    {
        return length;
    }

    void setLength(int length)
    {
        this.length = length;
    }

    String getCommunicationMode()
    {
        return communicationMode;
    }

    void setCommunicationMode(String communicationMode)
    {
        this.communicationMode = communicationMode;
    }
}

class ParseData
{
    late int startcode;
    late int deviceNo;
    late int cmd;
    late int bcc;
    late int seq;
    late int len;
    int headCount = 0;
    int dataCount = 0;
    List<int> buffer = [];
    List<int> bufferLen = [];
}