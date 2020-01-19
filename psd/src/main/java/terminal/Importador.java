package main.java.terminal;

import java.util.Scanner;
import java.io.IOException;
import java.net.Socket;
import java.net.SocketException;
import java.time.LocalDate;

import org.zeromq.SocketType;
import org.zeromq.ZMQ;
import org.zeromq.ZContext;

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
		System.out.println("Importador: Shutdown Output");

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
           System.out.println("Importador: Username");
            String username = scanner.nextLine();

            System.out.println("Importador: Password");
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
                System.out.println("Importador: Palavra passe incorreta");
                return authentication(scanner, rm, sm);
            }
            else{
                System.out.println("Importador: Entrou com sucesso");
            	return lc.getUsername();
            }
        }
        catch(IOException exc){
        	System.out.println("Importador: Deu asneira");
        }
        
        return null;
	}
}


class LeitorImportador implements Runnable{
	private Socket cs;
	private ZMQ.Context context;
	private ZMQ.Socket socket;
	private Notifications notifications;

	public LeitorImportador(Socket s, Notifications n){
		this.cs = s;
		this.context = ZMQ.context(2);
    	this.socket = context.socket(ZMQ.REQ);
    	this.notifications = n;
	}

	public void run(){
		try{
			ReadMessage rm = new ReadMessage(cs);
			this.socket.connect("tcp://localhost:5555");
			while(!this.cs.isClosed()){
				byte[] res = rm.receiveMessage();
				ImpSyn syn = ImpSyn.parseFrom(res);

				if(syn.getType().equals(ImpSyn.OpType.FINISH)){
					byte[] negotiation = rm.receiveMessage();
					ConfirmNegotiations nc = ConfirmNegotiations.parseFrom(negotiation);
					System.out.println("Importador: Recebi todos os produtos que fiz oferta");
					System.out.println(nc);
				}

				else if(syn.getType().equals(ImpSyn.OpType.OFFER)){
					byte[] bus = rm.receiveMessage();
					BusinessConfirmation bc = BusinessConfirmation.parseFrom(bus);
					if(bc.getResponse()){
						String str = bc.getFabricante() + "," + bc.getProduto();
						System.out.println(str);
						this.notifications.subscribe(str);
						this.socket.send("Importador," + str);
						byte[] b = socket.recv();
						System.out.println("Importador: O produto " + bc.getProduto() + " do fabricante " + bc.getFabricante() 
							+ " foi adicionado com sucesso");
					}
					else{
						System.out.println("Importador: O produto " + bc.getProduto() + " do fabricante " + bc.getFabricante() + " não foi adicionado");
					}
				}
			}
			System.out.println("Importador: Fechei");
		}
		catch(Exception e){
			System.out.println("Importador: Deu Exceção no LeitorImportador ");
			e.printStackTrace();
		}
	}
}