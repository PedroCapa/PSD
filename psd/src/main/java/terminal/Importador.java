package main.java.terminal;

import java.net.*;
import java.io.*;
import java.time.LocalDate;
import java.util.Scanner;
import java.util.Random;

//Copiar as coisas do Importador acerca da autenticação envio e receção de mensagens
import main.proto.Protos.Syn;

public class Importador{

	public static void main(String[] args) throws IOException, InterruptedException, SocketException{
		int port = Integer.parseInt(args[0]);
		Socket cs = new Socket("127.0.0.1", port);
		SendMessage sm = new SendMessage(cs);
		BufferedReader teclado = new BufferedReader(new InputStreamReader(cs.getInputStream()));
		Scanner scanner = new Scanner(System.in);

		//Depois substituir para uma mensagem so com protobuf
		Syn syn = Syn.newBuilder().
						setType(Syn.Type.IMP).
						build();
		byte[] bsyn = syn.toByteArray();
		sm.sendServer(bsyn);
		String user = authentication(scanner, teclado, sm);


		Notifications n = new Notifications(sm, true, user);
		Thread not = new Thread(n);
		not.start();
		

		LeitorImportador l = new LeitorImportador(cs, n);
		Thread t = new Thread(l);
		t.start();


		String current;
		while(scanner.hasNextLine()){
			current = scanner.nextLine();
			String[] arrOfStr = current.split(",");
			if(arrOfStr[0].equals("offer")){
				LocalDate ldt = LocalDate.now();
				current = current + ldt.toString() + ",";
			}
			//Criar os objetos deste lado para depois encriptar
			//Fazer encode dos objetos e enviar
			byte[] c = current.getBytes();
			sm.sendServer(c);
		}

		System.out.println("Shutdown Output");

		cs.shutdownOutput();
		teclado.close();
	}

	public static String authentication(Scanner scanner, BufferedReader teclado, SendMessage sm){
		try{
            //Ler do scanner nome e pass
            System.out.println("Username");
            String username = scanner.nextLine();
            sm.sendServer(username.getBytes());

            System.out.println("Password");
            String password = scanner.nextLine();
            sm.sendServer(password.getBytes());

            //Enviar para servidor a autenticação
            String response = teclado.readLine();
			String[] arrOfStr = response.split(",");

			System.out.println("Importador: Recebi" + response);

            if(arrOfStr[0].equals("-1")){
                System.out.println("Palavra passe incorreta");
                return authentication(scanner, teclado, sm);
            }
            else if(arrOfStr[0].equals("1")){
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
			System.out.println("Deu Exceção no LeitorImportador " + e.getMessage());
		}
	}
}