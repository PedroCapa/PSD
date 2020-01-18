package main.java.terminal;

import java.util.Scanner;
import java.io.IOException;
import java.net.Socket;
import java.net.SocketException;

import org.zeromq.SocketType;
import org.zeromq.ZMQ;
import org.zeromq.ZContext;

import main.proto.Protos.Syn;
import main.proto.Protos.Login;
import main.proto.Protos.LoginConfirmation;
import main.proto.Protos.Production;
import main.proto.Protos.Notification;

public class Fabricante{

	public static void main(String[] args) throws IOException, InterruptedException, SocketException{
		int port = Integer.parseInt(args[0]);
		Socket cs = new Socket("127.0.0.1", port);
		SendMessage sm = new SendMessage(cs);
		ReadMessage rm = new ReadMessage(cs);
		Scanner scanner = new Scanner(System.in);

		Syn syn = Syn.newBuilder().
						setType(Syn.Type.FAB).
						build();
		byte[] bsyn = syn.toByteArray();
		sm.sendServer(bsyn);
		
		String user = authentication(scanner, rm, sm);

		Notifications n = new Notifications(sm, false, user);
		Thread not = new Thread(n);
		not.start();
		
		LeitorFabricante l = new LeitorFabricante(cs, n);
		Thread t = new Thread(l);
		t.start();


		String current;
		while(scanner.hasNextLine()){
			current = scanner.nextLine();
			String[] arrOfStr = current.split(",");

			if(arrOfStr.length >= 5 && isNumeric(arrOfStr[1]) && isNumeric(arrOfStr[2]) && isNumeric(arrOfStr[3])){
				int min = Integer.parseInt(arrOfStr[1]);	
				int max = Integer.parseInt(arrOfStr[2]);	
				int price = Integer.parseInt(arrOfStr[3]);	
				Production product = Production.newBuilder().
												setProductName(arrOfStr[0]).
												setMin(min).
												setMax(max).
												setPrice(price).
												setData(arrOfStr[4]).
												build();

				//Talvez ter o Syn
				//Colocar o Syn em bytes
				byte[] prod = product.toByteArray();
				sm.sendServer(prod);//Enviar duas mensagens em vez de uma
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
            //Ler do scanner nome e pass
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
			ReadMessage rm = new ReadMessage(cs);
			this.socket.connect("tcp://localhost:5555");
			while(!this.cs.isClosed()){
				byte[] res = rm.receiveMessage();
		        Syn syn = Syn.parseFrom(res);
		        /*
				if(syn.get){
					//No caso de ser um finish receber a lista de Negocios
					//----Passar de byte[] para Lista de Negocios
					System.out.println(); //Imprimir a lista de negocios
				}
				else if(syn.get){
					//No caso de ser apenas a resposta a um Produto se foi confirmada
					//byte[] b = rm.receiveMessage();
					//----Transformar os bytes numa estrutura
					//this.notifications.subscribe(Estrutura.getQQ() + "," + Estrutura.getQQ());
					//this.socket.send(Estrutura.getQQ() + "," + Estrutura.getQQ());
					byte[] b = socket.recv();
				}
				*/
			}
			System.out.println("Fechei");
		}
		catch(Exception e){
			System.out.println("Deu Exceção no Leitor " + e.getMessage());
		}
	}
}
