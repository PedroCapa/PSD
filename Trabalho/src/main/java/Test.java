import com.ericsson.otp.erlang.*;

public class Test
{

    public static void main(String[] args) throws Exception

         {

                OtpNode myNode = new OtpNode("server");

                OtpMbox myMbox = myNode.createMbox("countserver");

                OtpErlangObject myObject;

                OtpErlangTuple myMsg;

                OtpErlangPid from;

                OtpErlangString command;

                Integer counter = 0;

           OtpErlangAtom myAtom = new OtpErlangAtom("ok");

           while(counter >= 0) try

                {
                        System.out.println("Vou enviar " + myMbox.self());


                        //myMsg = (OtpErlangTuple) myObject;

                        //from = (OtpErlangPid) myMsg.elementAt(0);

                        //command = (OtpErlangString) myMsg.elementAt(1);

                        // here you may want to check the value of command

                        OtpErlangObject[] reply = new OtpErlangObject[2];

                        reply[0] = myAtom;

                        reply[1] = new OtpErlangInt(counter);

                        OtpErlangTuple myTuple = new OtpErlangTuple(reply);

                        myMbox.send("client@pedro", myTuple);

                        System.out.println("Vou receber");
                        
                        myObject = myMbox.receive();
                        
                        counter++;

        } catch(OtpErlangExit e)

                  {

                        break;

                  }

        }

}

/*

*/