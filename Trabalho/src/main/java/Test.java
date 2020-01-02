import com.ericsson.otp.erlang.*;

import java.net.*;
import java.io.*;

public class Test{

    public static void main(String[] args) throws IOException, InterruptedException, SocketException{
        Socket cs = new Socket("127.0.0.1", 9999);
        PrintWriter out = new PrintWriter(cs.getOutputStream(), true);
        BufferedReader teclado = new BufferedReader(new InputStreamReader(System.in));
        try{
            LeitorCliente l = new LeitorCliente(cs);
            Thread t = new Thread(l);
            t.start();

            String current = "Enviei uma mensagen";

            while((current = teclado.readLine()) != null){
                out.println(current);
            }

        }
        catch(Exception e){
            System.out.println("Deu merda\n");
            System.out.println(e.getMessage());
        }
        finally{
            System.out.println("Shutdown Output");

            cs.shutdownOutput();
            teclado.close();
            out.close();
        }
    }
}