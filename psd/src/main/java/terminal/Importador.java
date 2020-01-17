package main.java.terminal;

import java.util.Scanner;
import java.io.IOException;
import java.net.Socket;
import java.net.SocketException;
import java.time.LocalDate;

import main.proto.Protos.Syn;
import main.proto.Protos.Login;
import main.proto.Protos.LoginConfirmation;
import main.proto.Protos.Negotiation;

public class Importador{

	public static void main(String[] args) throws IOException, InterruptedException, SocketException{
		int port = Integer.parseInt(args[0]);
		Socket cs = new Socket("127.0.0.1", port);
		SendMessage sm = new SendMessage(cs);
		ReadMessage rm = new ReadMessage(cs);
		Scanner scanner = new Scanner(System.in);

		Syn syn = Syn.newBuilder().
						setType(Syn.Type.IMP).
						build();
		byte[] bsyn = syn.toByteArray();
		sm.sendServer(bsyn);
		
		String user = authentication(scanner, rm, sm);

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
			
			if(arrOfStr.length >= 5 && isNumeric(arrOfStr[2]) && isNumeric(arrOfStr[3])){
				int price = Integer.parseInt(arrOfStr[2]);	
				int amount = Integer.parseInt(arrOfStr[3]);	
				Negotiation neg = Negotiation.newBuilder().
												setImporterOffer(arrOfStr[0]).
												setProductName(arrOfStr[1]).
												setPrice(price).
												setAmount(amount).
												setData(LocalDate.now().toString()).
												build();

			//Criar o Syn e converter para Bytes
			byte[] c = neg.toByteArray();
			sm.sendServer(c);//Enviar duas mensagens
			}
		}
		System.out.println("Shutdown Output");

		cs.shutdownOutput();

	}

	public static boolean isNumeric(String strNum) {
	    if (strNum == null) {
	        return false;
	    }
	    try {
	        int d = Integer.parseInt(strNum);
	    } catch (NumberFormatException nfe) {
	        return false;
	    }
	    return true;
	}

	public static String authentication(Scanner scanner, ReadMessage rm, SendMessage sm){
		try{
           System.out.println("Username");
            String username = scanner.nextLine();

            System.out.println("Password");
            String password = scanner.nextLine();

            //enviar aqui em baixo
            Login login = Login.newBuilder().
						setName(username).
						setPass(password).
						build();

			byte[] blogin = login.toByteArray();
			sm.sendServer(blogin);

			//Receber aqui
	        byte[] res = rm.receiveMessage();
	        LoginConfirmation lc = LoginConfirmation.parseFrom(res);
	        System.out.println(lc);

            if(!lc.getResponse()){
                System.out.println("Palavra passe incorreta");
                return authentication(scanner, rm, sm);
            }
            else if(lc.getResponse()){
                System.out.println("Entrou com sucesso");
            	return lc.getUsername();
            }
            /*
            else{
                System.out.println("Sessão iniciada com sucesso");
            	return ;
            }
            */
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
			ReadMessage rm = new ReadMessage(cs);
			while(!this.cs.isClosed()){
				byte[] res = rm.receiveMessage();
				Syn syn = Syn.parseFrom(res);
				/*
				if(syn.get){
					//No caso de enviar uma lista de Negocios
					//Ir buscar os bytes
					//Converter para Lista de Negocios
					//System.out.println(); //Da lista de Mensagens
				}

				else if(syn.getQQ){
					//No caso de ser uma resposta ao negocio ou seja se foi valido
					//Caso seja valido subscrever
					//this.notifications.subscribe(this.QQ + "," + this.QQ);
					System.out.println("Recebi coisas e foram aceites");
				}
				*/
			}
			System.out.println("Fechei");
		}
		catch(Exception e){
			System.out.println("Deu Exceção no LeitorImportador " + e.getMessage());
		}
	}
}