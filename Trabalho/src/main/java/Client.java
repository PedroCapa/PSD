import java.net.*;
import java.io.*;

public class Client{

	public static void main(String[] args) throws IOException, InterruptedException, SocketException{
		int port = Integer.parseInt(args[0]);
		Socket cs = new Socket("127.0.0.1", 9999);

		PrintWriter out = new PrintWriter(cs.getOutputStream(), true);
		BufferedReader teclado = new BufferedReader(new InputStreamReader(System.in));

		LeitorCliente l = new LeitorCliente(cs);
		Thread t = new Thread(l);
		t.start();

		String current;

		while((current = teclado.readLine()) != null){
			out.println(current);
		}

		try{
			Thread.sleep(100000);
		}
		catch(Exception e){
			System.out.println(e.getMessage());
		}

		System.out.println("Shutdown Output");

		cs.shutdownOutput();
		teclado.close();
		out.close();
	}
}


class LeitorCliente implements Runnable{
	private Socket cs;

	public LeitorCliente(Socket s){
		this.cs = s;
	}

	public void run(){
		try{
			BufferedReader in = new BufferedReader(new InputStreamReader(cs.getInputStream()));
			while(!this.cs.isClosed()){
				String eco = in.readLine();
				if(eco != null)
					System.out.println("Server: " + eco);
			}
			System.out.println("Fechei");
		}
		catch(Exception e){
			System.out.println();
		}
	}
}