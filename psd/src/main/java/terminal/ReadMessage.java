package main.java.terminal;

import java.net.Socket;
import java.io.InputStream;
import java.io.IOException;

class ReadMessage{
	private InputStream is;

	public ReadMessage(Socket cs){
        try{
		  this.is = cs.getInputStream();
        }
        catch(IOException exc){
            exc.printStackTrace();
        }
	}

	public byte[] receiveMessage(){
		try{
            byte[] res = receive(is);
        }
        catch(IOException exc){
            exc.printStackTrace();
        }
        return null;
	}

	public byte[] receive(InputStream is) throws IOException{
        
        try{
            byte[] tmp = new byte[1024];
            int count = 0;
            count = is.read(tmp);
            byte[] res = new byte[count];

            for(int i = 0; i < count; i++){
                res[i] = tmp[i];
            }
            return res;
        }
        catch(IOException exc){
            exc.printStackTrace();
        }
        return (new byte[1]);
    }
}