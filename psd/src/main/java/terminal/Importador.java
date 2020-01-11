package main.java.terminal;

import java.net.*;
import java.io.*;
import java.time.LocalDate;
import java.util.Scanner;
import java.util.Random;

//Copiar as coisas do Importador acerca da autenticação envio e receção de mensagens


public class Importador{

	public static void main(String[] args) throws IOException, InterruptedException, SocketException{
		int port = Integer.parseInt(args[0]);
		Socket cs = new Socket("127.0.0.1", port);

		PrintWriter out = new PrintWriter(cs.getOutputStream(), true);
		BufferedReader teclado = new BufferedReader(new InputStreamReader(System.in));

		Notifications n = new Notifications(out);
		Thread not = new Thread(n);
		not.start();
		
		//Aqui começa o leitor cliente
		LeitorImportador l = new LeitorImportador(cs, n);
		Thread t = new Thread(l);
		t.start();

		//Colocar aqui a autenticação 

		out.println("1");

		String current;
		Scanner scanner = new Scanner(System.in);
		while(scanner.hasNextLine()){
			current = scanner.nextLine();
			String[] arrOfStr = current.split(",");
			if(arrOfStr[0].equals("offer")){
				LocalDate ldt = LocalDate.now();
				current = current + ldt.toString() + ",";
			}
			//Criar os objetos deste lado para depois encriptar
			//Fazer encode dos objetos e enviar
			out.println(current);
		}

		System.out.println("Shutdown Output");

		cs.shutdownOutput();
		teclado.close();
		out.close();
	}
}


class LeitorImportador implements Runnable{
	private Socket cs;
	private Notifications notifications;

	public LeitorImportador(Socket s, Notifications n){
		this.cs = s;
    	this.notifications = n;
	}

	public void run(){
		try{
			BufferedReader in = new BufferedReader(new InputStreamReader(cs.getInputStream()));
			while(!this.cs.isClosed()){
				String eco = in.readLine();
				if(eco != null)
					System.out.println("Server: " + eco);
				String[] arrOfStr = eco.split(",");
				//Colocar aqui no caso de o pedido ser para responder por causa do pedido ter acabado
				if(arrOfStr.length == 2){//Fabricante,Produto,Quantidade,Preco
					this.notifications.subscribe(arrOfStr[0] + "," + arrOfStr[1]);
					System.out.println("Recebi coisas e foram aceites");
				}
			}
			System.out.println("Fechei");
		}
		catch(Exception e){
			System.out.println();
		}
	}
}