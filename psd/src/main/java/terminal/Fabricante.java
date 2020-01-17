package main.java.terminal;

import java.net.*;
import java.io.*;
import java.util.Scanner;
import java.util.Random;

import org.zeromq.SocketType;
import org.zeromq.ZMQ;
import org.zeromq.ZContext;

import main.proto.Protos.Syn;
import main.proto.Protos.Login;
import main.proto.Protos.LoginConfirmation;
import main.proto.Protos.Production;

public class Fabricante{

	public static void main(String[] args) throws IOException, InterruptedException, SocketException{
		int port = Integer.parseInt(args[0]);
		Socket cs = new Socket("127.0.0.1", port);
		SendMessage sm = new SendMessage(cs);
		InputStream is = cs.getInputStream();
		Scanner scanner = new Scanner(System.in);

		Syn syn = Syn.newBuilder().
						setType(Syn.Type.FAB).
						build();
		byte[] bsyn = syn.toByteArray();
		sm.sendServer(bsyn);
		
		String user = authentication(scanner, is, sm);


		Notifications n = new Notifications(sm, false, user);
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
				byte[] prod = product.toByteArray();
				sm.sendServer(prod);
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

	public static byte[] receive(InputStream is){
        
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

	public static String authentication(Scanner scanner, InputStream is, SendMessage sm){
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
	        byte[] res = receive(is);
	        LoginConfirmation lc = LoginConfirmation.parseFrom(res);
	        System.out.println(lc);

            if(!lc.getResponse()){
                System.out.println("Palavra passe incorreta");
                return authentication(scanner, is, sm);
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
			BufferedReader in = new BufferedReader(new InputStreamReader(cs.getInputStream()));
			this.socket.connect("tcp://localhost:5555");
			while(!this.cs.isClosed()){
				String eco = in.readLine();
				//Colocar aqui outro readLine no caso do anterior ser apenas um Syn
				if(eco != null)
					System.out.println("Recebi: " + eco);
				String[] arrOfStr = eco.split(",");
				if(arrOfStr.length == 3){
					System.out.println("Vou enviar para o servidor do ZeroMQ " + arrOfStr[0] + "		" + arrOfStr[1]);
					this.notifications.subscribe(arrOfStr[0] + "," + arrOfStr[1]);
					this.socket.send(arrOfStr[0] + "," + arrOfStr[1]);
					byte[] b = socket.recv();
				}
			}
			System.out.println("Fechei");
		}
		catch(Exception e){
			System.out.println("Deu Exceção no Leitor " + e.getMessage());
		}
	}
}

class Notifications implements Runnable{

	private ZContext zcont = new ZContext();
	private ZMQ.Socket subscriber;
	private SendMessage sm;
	private boolean importador;
	private String username;

	public Notifications(SendMessage sm, boolean importador, String username){
    	this.subscriber = zcont.createSocket(SocketType.SUB);
    	this.sm = sm;
    	this.importador = importador;
    	this.username = username;
	}

	public void run(){
        
        System.out.println("Ready to receive notifications");
        this.subscriber.connect("tcp://localhost:6666");

        while(!Thread.currentThread().isInterrupted()){
        	String channel = subscriber.recvStr();
        	System.out.println("Acabou o tempo do produto " + channel);
        	if(importador){
				
        		sm.sendServer(("over," + channel + "," + username + ",").getBytes());
        	}
        	else{

        		sm.sendServer(("over," + channel + ",").getBytes());
        	}
        }
    }

    public void subscribe(String prod){
        this.subscriber.subscribe(prod);
    }
}

class SendMessage{
	private OutputStream out;

	public SendMessage(Socket cs){
		try{
			this.out = cs.getOutputStream();
		}
		catch(Exception e){
			System.out.println("Deu exceção no SendMessage: " + e.getMessage());
		}
	}

	public synchronized void sendServer(byte[] send){
		try{
			out.write(send);
		}
		catch(IOException e){
			e.getMessage();
		}
	}

	public synchronized void sendSynSeerver(byte[] type, byte[] send){
		try{
			out.write(type);
			out.write(send);
		}
		catch(IOException e){
			e.getMessage();
		}
	}
}