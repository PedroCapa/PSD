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
import main.proto.Protos.ImpSyn;
import main.proto.Protos.ConfirmNegotiations;
import main.proto.Protos.BusinessConfirmation;

public class Importador{

	public static void main(String[] args) throws IOException, InterruptedException, SocketException{
		int port = Integer.parseInt(args[0]);
		Socket cs = new Socket("127.0.0.1", port);
		SendMessage sm = new SendMessage(cs);
		ReadMessage rm = new ReadMessage(cs);
		Scanner scanner = new Scanner(System.in);

		sendSyn(sm);
		
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
			
			if(arrOfStr.length >= 4 && isNumeric(arrOfStr[2]) && isNumeric(arrOfStr[3])){
				sendNegotiation(sm, arrOfStr);
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

	public static void sendSyn(SendMessage sm){
		Syn syn = Syn.newBuilder().
						setType(Syn.Type.IMP).
						build();
		byte[] bsyn = syn.toByteArray();
		sm.sendServer(bsyn);
	}

	public static void sendNegotiation(SendMessage sm, String[] arrOfStr){
		int price = Integer.parseInt(arrOfStr[2]);
		int amount = Integer.parseInt(arrOfStr[3]);

		Negotiation neg = Negotiation.newBuilder().
										setFabricante(arrOfStr[0]).
										setProductName(arrOfStr[1]).
										setPrice(price).
										setAmount(amount).
										setData(LocalDate.now().toString()).
										build();

		ImpSyn impsyn = ImpSyn.newBuilder().
							  setType(ImpSyn.OpType.OFFER).
							  build();

		byte[] ims = impsyn.toByteArray();
		byte[] c = neg.toByteArray();
		sm.sendServer(ims, c);
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

            if(!lc.getResponse()){
                System.out.println("Palavra passe incorreta");
                return authentication(scanner, rm, sm);
            }
            else{
                System.out.println("Entrou com sucesso");
            	return lc.getUsername();
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
			ReadMessage rm = new ReadMessage(cs);
			while(!this.cs.isClosed()){
				byte[] res = rm.receiveMessage();
				ImpSyn syn = ImpSyn.parseFrom(res);

				if(syn.getType().equals(ImpSyn.OpType.OVER)){
					byte[] negotiation = rm.receiveMessage();
					ConfirmNegotiations nc = ConfirmNegotiations.parseFrom(negotiation);
					System.out.println(nc);
					System.out.println();
				}

				else if(syn.getType().equals(ImpSyn.OpType.OFFER)){
					byte[] bus = rm.receiveMessage();
					BusinessConfirmation bc = BusinessConfirmation.parseFrom(bus);
					if(bc.getResponse()){
						this.notifications.subscribe(bc.getFabricante() + "," + bc.getProduto());
						System.out.println("O produto " + bc.getProduto() + " do fabricante " + bc.getFabricante() + " foi adicionado com sucesso");
					}
					else{
						System.out.println("O produto " + bc.getProduto() + " do fabricante " + bc.getFabricante() + " não foi adicionado");
					}
				}
			}
			System.out.println("Fechei");
		}
		catch(Exception e){
			System.out.println("Deu Exceção no LeitorImportador " + e.getMessage());
		}
	}
}