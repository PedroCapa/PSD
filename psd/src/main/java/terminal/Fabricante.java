package main.java.terminal;

import java.net.*;
import java.io.*;
import java.util.Scanner;
import java.util.Random;

import org.zeromq.SocketType;
import org.zeromq.ZMQ;
import org.zeromq.ZContext;

import main.proto.Protos.Login;

public class Fabricante{

	public static void main(String[] args) throws IOException, InterruptedException, SocketException{
		int port = Integer.parseInt(args[0]);
		Socket cs = new Socket("127.0.0.1", port);
		PrintWriter out = new PrintWriter(cs.getOutputStream(), true);
		BufferedReader teclado = new BufferedReader(new InputStreamReader(cs.getInputStream()));
		Scanner scanner = new Scanner(System.in);


		out.println("1");
		out.println("fab");
		String user = authentication(scanner, teclado, out);


		Notifications n = new Notifications(out, false, user);
		Thread not = new Thread(n);
		not.start();
		

		LeitorFabricante l = new LeitorFabricante(cs, n);
		Thread t = new Thread(l);
		t.start();


		String current;
		while(scanner.hasNextLine()){
			current = scanner.nextLine();
			//Criar os objetos deste lado para depois encriptar
			//Fazer encode dos objetos e enviar
			out.println(current);
		}

		System.out.println("Shutdown Output");

		cs.shutdownOutput();
		teclado.close();
		out.close();
	}


	public static String authentication(Scanner scanner, BufferedReader teclado, PrintWriter out){
		try{
            //Ler do scanner nome e pass
            System.out.println("Username");
            String username = scanner.nextLine();
            out.println(username);

            System.out.println("Password");
            String password = scanner.nextLine();
            out.println(password);

            //Enviar para servidor a autenticação
            String response = teclado.readLine();
			String[] arrOfStr = response.split(",");

            if(arrOfStr[0].equals("-1\n")){
                System.out.println("Palavra passe incorreta");
                return authentication(scanner, teclado, out);
            }
            else if(arrOfStr[0].equals("1\n")){
                System.out.println("Conta criada com sucesso");
            	return arrOfStr[1];
            }
            else{
                System.out.println("Sessão iniciada com sucesso");
            	return arrOfStr[1];
            }
        }
        catch(IOException exc){
        	System.out.println("Deu asneira");
        }
        
        return null;
	}
}


class LeitorFabricante implements Runnable{
	private Socket cs;
	private ZMQ.Context context;
	private ZMQ.Socket socket;
	private Notifications notifications;

	public LeitorFabricante(Socket s, Notifications n){
		this.cs = s;
		this.context = ZMQ.context(2);
    	this.socket = context.socket(ZMQ.REQ);
    	this.notifications = n;
	}

	public void run(){
		try{
			BufferedReader in = new BufferedReader(new InputStreamReader(cs.getInputStream()));
			this.socket.connect("tcp://localhost:5555");
			while(!this.cs.isClosed()){
				String eco = in.readLine();
				if(eco != null)
					System.out.println("Server: " + eco);
				String[] arrOfStr = eco.split(",");
				if(arrOfStr.length == 3){
					System.out.println("Vou enviar para o servidor do ZeroMQ");
					this.notifications.subscribe(arrOfStr[0] + "," + arrOfStr[1]);
					this.socket.send(arrOfStr[0] + "," + arrOfStr[1]);
				}
				//Colocar aqui no caso de o pedido ser para responder por causa do pedido ter acabado
				if(arrOfStr.length == 4){//Importador,Produto,Ammount,Price
					System.out.println("Este Importador: " + arrOfStr[0] + "comprou o teu" + "Produto: " + arrOfStr[1]);
				}
			}
			System.out.println("Fechei");
		}
		catch(Exception e){
			System.out.println();
		}
	}
}

class Notifications implements Runnable{

	private ZContext zcont = new ZContext();
	private ZMQ.Socket subscriber;
	private PrintWriter out;
	private boolean importador;
	private String username;

	public Notifications(PrintWriter out, boolean importador, String username){
    	this.subscriber = zcont.createSocket(SocketType.SUB);
    	this.out = out;
    	this.importador = importador;
    	this.username = username;
	}

	public void run(){
        
        System.out.println("Ready to receive notifications");
        this.subscriber.connect("tcp://localhost:6666");

        while(!Thread.currentThread().isInterrupted()){
        	String channel = subscriber.recvStr();
        	System.out.println("Acabou o tempo do produto " + channel);
        	if(importador)	
        		out.println("over," + channel + "," + username);
        	else
        		out.println("over," + channel + ",");
        }
    }
    //Mudar o tipo de subscrição
    public void subscribe(String prod){
        this.subscriber.subscribe(prod);
    }
}