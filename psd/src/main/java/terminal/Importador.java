package main.java.terminal;

import java.net.*;
import java.io.*;
import java.time.LocalDate;
import java.util.Scanner;
import java.util.Random;

//Copiar as coisas do Importador acerca da autenticação envio e receção de mensagens
import main.proto.Protos.Syn;
import main.proto.Protos.Login;
import main.proto.Protos.LoginConfirmation;
import main.proto.Protos.Negotiation;

public class Importador{

	public static void main(String[] args) throws IOException, InterruptedException, SocketException{
		int port = Integer.parseInt(args[0]);
		Socket cs = new Socket("127.0.0.1", port);
		SendMessage sm = new SendMessage(cs);
		InputStream is = cs.getInputStream();
		Scanner scanner = new Scanner(System.in);

		//Depois substituir para uma mensagem so com protobuf
		Syn syn = Syn.newBuilder().
						setType(Syn.Type.IMP).
						build();
		byte[] bsyn = syn.toByteArray();
		sm.sendServer(bsyn);
		String user = authentication(scanner, is, sm);


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

			//Talvez ter o Syn
			byte[] c = neg.toByteArray();
			sm.sendServer(c);
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
				//Colocar aqui outro readLine no caso do anterior ser apenas um Syn
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